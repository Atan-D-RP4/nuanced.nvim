local M = {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1010,
}

M.keys = {
  { '<leader>.', '<cmd>lua Snacks.scratch()<CR>', desc = 'Toggle Scratch Buffer' },
  { '<leader>S', '<cmd>lua Snacks.scratch.select()<CR>', desc = 'Select Scratch Buffer' },
  { '<leader>dn', '<cmd>lua Snacks.notifier.hide()<CR>', desc = 'Dismiss All Notifications' },
  { '<leader>cR', '<cmd>lua Snacks.rename.rename_file()<CR>', desc = 'Rename File' },
  { '<leader>gB', '<cmd>lua Snacks.gitbrowse()<CR>', desc = '[G]it [B]rowse', mode = { 'n', 'v' } },

  -- Create some toggle mappings
  { '<leader>tz', '<cmd>lua Snacks.zen()<CR>', desc = 'Toggle Zen Mode' },
  { '<leader>tZ', '<cmd>lua Snacks.zen.zoom()<CR>', desc = 'Toggle Zoom' },
  { '<leader>ts', "<cmd>lua Snacks.toggle.option('spell', { name = 'Spelling' }):toggle()<CR>", desc = '[T]oggle [S]pell' },
  { '<leader>tw', "<cmd>lua Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle()<CR>", desc = 'Toggle [W]rap' },
  {
    '<leader>tL',
    "<cmd>lua Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):toggle()<CR>",
    desc = '[T]oggle [R]elative Numbers',
  },
  { '<leader>td', '<cmd>lua Snacks.toggle.diagnostics():toggle()<CR>', desc = '[T]oggle Lsp [D]iagnosticse' },
  { '<leader>tl', '<cmd>lua Snacks.toggle.line_number():toggle()<CR>', desc = '[T]oggle [L]ine Numbers' },
  { '<leader>tt', '<cmd>lua Snacks.toggle.treesitter():toggle()<CR>', desc = '[T]oggle [T]reesitter Highlight' },
  { '<leader>ti', '<cmd>lua Snacks.toggle.indent():toggle()<CR>', desc = '[T]oggle [I]ndent' },
  { '<leader>tf', '<cmd>lua Snacks.toggle.dim():toggle()<CR>', desc = '[T]oggle [F]ocus' },
  { '<leader>tn', '<cmd>lua Snacks.picker.notifications()<CR>', desc = 'Notification History' },
  {
    '<leader>tc',
    function()
      local flag = vim.o.statuscolumn == ''
      if flag then
        vim.o.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
      else
        vim.o.statuscolumn = ''
      end
      vim.notify(
        'Snacks statuscolumn ' .. (flag and 'disabled' or 'enabled'),
        (flag and vim.log.levels.WARN or vim.log.levels.INFO),
        { title = 'Snacks Statuscolumn' }
      )
    end,
    desc = '[T]oggle snacks statuscolumn',
  },

  -- Picker maps
  { '<leader>ef', '<cmd>lua Snacks.picker.buffers({sort_lastused=true})<CR>', desc = '[E]xisting Buffers [F]zf', mode = 'n' },
  { '<leader>eo', '<cmd>lua Snacks.picker.explorer()<CR>', desc = '[E]xplorer [O]pen', mode = 'n' },

  { '<leader>fp', '<cmd>lua Snacks.picker.pickers()<CR>', desc = '[F]zf [P]ickers', mode = 'n' },
  { '<leader>fr', '<cmd>lua Snacks.picker.registers({confirm = { "copy", "close" }})<CR>', desc = '[F]zf [K]eymaps', mode = 'n' },
  { '<leader>fh', '<cmd>lua Snacks.picker.help()<CR>', desc = '[F]zf [H]elp tags', mode = 'n' },
  { '<leader>fk', '<cmd>lua Snacks.picker.keymaps()<CR>', desc = '[F]zf [K]eymaps', mode = 'n' },
  { '<leader>fo', '<cmd>lua Snacks.picker.recent()<CR>', desc = '[F]zf [O]ld files', mode = 'n' },
  { '<leader>fl', '<cmd>lua Snacks.picker.grep()<CR>', desc = '[F]zf [G]rep files', mode = 'n' },
  { '<leader>ff', '<cmd>lua Snacks.picker.files()<CR>', desc = '[F]zf [F] files', mode = 'n' },
  { '<leader>f:', '<cmd>lua Snacks.picker.command_history()<CR>', desc = '[F]zf [C]ommands', mode = 'n' },
  { '<leader>ft', '<cmd>lua Snacks.picker.treesitter()<CR>', desc = '[F]zf [T]reesitter [S]ymbols', mode = 'n' },

  { '<leader>gt', '<cmd>lua Snacks.picker.git_branches()<CR>', desc = '[G]it [t]oggle branches picker', mode = 'n' },
  -- {
  --   '<leader>tb',
  --   "<cmd>lua Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):toggle()<CR>",
  --   desc = '[T]oggle [B]ackground',
  -- },
  {
    '<C-w><C-t>',
    function()
      if #Snacks.terminal.list() > 0 then
        Snacks.terminal.toggle()
      else
        Snacks.terminal.open()
      end
    end,
    mode = { 'n', 't' },
    desc = '[T]oggle [T]erminal',
  },
}

---@module 'snacks'
---@type snacks.Config
M.opts = {
  dim = {
    -- your dim configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },

  profiler = { enabled = false },
  quickfile = { enabled = true },
  scope = { enabled = false }, -- tpope/vim-sleuth is just better for this
  indent = { enabled = true },
  input = { enabled = true },
  rename = { enabled = true },
  image = { enabled = true },
  explorer = { enabled = true },
  picker = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  styles = { notification = { wo = { wrap = true } } }, -- Wrap notifications
  scroll = { enabled = false },
  statuscolumn = { enabled = false },
  words = { enabled = false },
}

M.opts.bigfile = {
  enabled = true,
  size = 0.5 * 1024 * 1024, -- 1.5MB
  line_length = 1000, -- average line length (useful for minified files)
  -- Enable or disable features when big file detected
  ---@param ctx {buf: number, ft:string}
  setup = function(ctx)
    if vim.fn.exists ':NoMatchParen' ~= 0 then
      vim.cmd [[NoMatchParen]]
    end
    Snacks.util.wo(0, { relativenumber = false, number = false, foldmethod = 'manual', statuscolumn = '', conceallevel = 0 })
    Snacks.util.bo(0, { bufhidden = 'unload', undolevels = -1, swapfile = false })
    -- show ruler
    vim.o.ruler = true
    vim.b.minianimate_disable = true
    vim.b.minihipatterns_disable = true
    vim.treesitter.stop(0)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ctx.buf) then
        vim.bo[ctx.buf].syntax = ctx.ft
      end
    end)
  end,
}

M.opts.terminal = {
  enabled = true,
  win = {
    position = 'float',
    border = 'rounded',
    keys = {
      ['<C-d>'] = {
        function(self)
          self:destroy()
        end,
        desc = 'Close Terminal',
        mode = { 't', 'n' },
      },
    },
  },
}

M.opts.dashboard = {
  enabled = false,
  preset = {
    ---@type fun(cmd:string, opts:table)|nil
    pick = nil,

    ---@type snacks.dashboard.Item[]
    keys = {
      { icon = ' ', key = 'a', desc = 'Pick Session', action = '<cmd>SessionPick<CR>' },
      { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
      { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
      -- { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
      { icon = ' ', key = 'G', desc = 'Git', action = '<cmd>Git ++curwin | Git log | wincmd H | wincmd l<CR>' },
      { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
      { icon = ' ', key = 'o', desc = 'File System', action = '<cmd>Oil<CR>' },
      { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
      { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
    },
  },
}

M.opts.picker = {
  matcher = {
    frecency = true,
    cwd_bonus = true,
  },
  actions = {
    cd_up = function(picker, _)
      picker:set_cwd(vim.fs.dirname(picker:cwd()))
      picker:find()
    end,

    cd_down = function(picker, _)
      local new_cwd = picker.list:current().text:match '([^/]+)/'
      if new_cwd and vim.fn.isdirectory(picker:cwd() .. '/' .. new_cwd) == 1 then
        picker:set_cwd(picker:cwd() .. '/' .. new_cwd)
        picker:find()
      end
    end,

    flash = function(picker)
      local err, flash = pcall(require, 'flash')
      if not err then
        vim.print 'You need to install flash.nvim to use this feature'
        return
      end
      flash.jump {
        pattern = '^',
        label = { after = { 0, 0 } },
        actions = {
          ['<C-l>'] = function(match, state)
            return false
          end,
        },
        search = {
          mode = 'search',
          exclude = {
            function(win)
              return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'snacks_picker_list'
            end,
          },
        },
        highlight = { backdrop = false },
        action = function(match)
          local idx = picker.list:row2idx(match.pos[1])
          picker.list:_move(idx, true, true)
          picker:action 'confirm'
        end,
      }
    end,
  },

  win = { input = { keys = { ['<C-l>'] = { 'flash', desc = 'flash', mode = { 'i', 'n' } } } } },

  sources = {
    explorer = {
      auto_close = true,
      jump = { close = true },
      layout = {
        layout = { height = 0.2, position = 'left' },
      },
    },

    files = {
      win = {
        input = {
          keys = {
            ['<C-j>'] = { 'cd_down', desc = 'cd_down', mode = { 'i', 'n' } },
            ['<C-k>'] = { 'cd_up', desc = 'cd_up', mode = { 'i', 'n' } },
          },
        },
      },
    },

    grep = {
      win = {
        input = {
          keys = {
            ['<C-j>'] = { 'cd_down', desc = 'cd_down', mode = { 'i', 'n' } },
            ['<C-k>'] = { 'cd_up', desc = 'cd_up', mode = { 'i', 'n' } },
          },
        },
      },
    },
    lsp_symbols = { layout = { preset = 'vscode', preview = 'main', layout = { border = 'rounded' } } },
    treesitter = { layout = { preset = 'vscode', preview = 'main', layout = { border = 'rounded' } } },
  },
}

M.init = function()
  vim.defer_fn(function()
    vim.ui.select = Snacks.picker.select
  end, 50)

  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    callback = function()
      -- Setup some globals for debugging (lazy-loaded)
      _G.dd = function(...)
        Snacks.debug.inspect(...)
      end
      _G.bt = function()
        Snacks.debug.backtrace()
      end
      vim.print = _G.dd -- Override print to use snacks for `:=` command
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'OilActionsPost',
    callback = function(event)
      if event.data.actions.type == 'move' then
        require('snacks').rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      end
    end,
  })
end

return M
