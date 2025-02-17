local M = {
  'folke/snacks.nvim',
  lazy = false,
}

---@type snacks.Config
M.opts = {
  picker = {
    sources = {
      explorer = {
        auto_close = true,
        jump = { close = true },
        layout = { layout = { position = 'right' } },
        win = { list = { keys = { ['<leader>l'] = require('flash').jump } } },
      },
    },
  },

  dim = {
    -- your dim configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
  profiler = { enabled = false },
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true }, -- tpope/vim-sleuth is just better for this
  indent = { enabled = true },
  input = { enabled = true },
  dashboard = { enabled = false },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  styles = {
    notification = {
      wo = { wrap = true }, -- Wrap notifications
    },
  },

  scroll = { enabled = false },
  statuscolumn = { enabled = false },
  words = { enabled = false },
}

M.init = function()
  -- if vim.fn.executable 'lazygit' == 1 then
  --   vim.tbl_map(function(map)
  --     require('nuance.core.utils').map(map[1], map[2], map[3], map[4] or {})
  --   end, {
  --     { '<leader>gf', '<cmd>lua Snacks.lazygit.log_file()<CR>', 'Lazygit Current File History' },
  --     { '<leader>gg', '<cmd>lua Snacks.lazygit()<CR>', 'Lazygit' },
  --     { '<leader>gl', '<cmd>lua Snacks.lazygit.log()<CR>', 'Lazygit Log (cwd)' },
  --   })
  -- end

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
end

M.keys = {
  { '<leader>z', '<cmd>lua Snacks.zen()<CR>', desc = 'Toggle Zen Mode' },
  { '<leader>Z', '<cmd>lua Snacks.zen.zoom()<CR>', desc = 'Toggle Zoom' },
  { '<leader>.', '<cmd>lua Snacks.scratch()<CR>', desc = 'Toggle Scratch Buffer' },
  { '<leader>S', '<cmd>lua Snacks.scratch.select()<CR>', desc = 'Select Scratch Buffer' },
  { '<leader>tn', '<cmd>lua Snacks.notifier.show_history()<CR>', desc = 'Notification History' },
  { '<leader>dn', '<cmd>lua Snacks.notifier.hide()<CR>', desc = 'Dismiss All Notifications' },
  { '<leader>dd', '<cmd>lua Snacks.bufdelete()<CR>', desc = 'Delete Buffer' },
  { '<leader>cR', '<cmd>lua Snacks.rename.rename_file()<CR>', desc = 'Rename File' },
  { '<leader>gB', '<cmd>lua Snacks.gitbrowse()<CR>', desc = 'Git Browse', mode = { 'n', 'v' } },

  { '<C-w>t', '<cmd>lua Snacks.terminal()<CR>', mode = { 'n', 't' }, desc = '[T]oggle [T]erminal' },
  { '<C-w><C-t>', '<cmd>lua Snacks.terminal()<CR>', mode = { 'n', 't' }, desc = '[T]oggle [T]erminal' },


  -- Create some toggle mappings
  { '<leader>ts', "<cmd>lua Snacks.toggle.option('spell', { name = 'Spelling' }):toggle()<CR>", desc = '[T]oggle [S]pell' },
  { '<leader>tw', "<cmd>lua Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle()<CR>", desc = 'Toggle [W]rap' },
  { '<leader>tL', "<cmd>lua Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):toggle()<CR>", desc = '[T]oggle [R]elative Numbers' },
  { '<leader>td', '<cmd>lua Snacks.toggle.diagnostics():toggle()<CR>', desc = '[T]oggl [D]iagnosticse' },
  { '<leader>tl', '<cmd>lua Snacks.toggle.line_number():toggle()<CR>', desc = '[T]oggle [L]ine Numbers' },
  { '<leader>tT', '<cmd>lua Snacks.toggle.treesitter():toggle()<CR>', desc = '[T]oggle [T]reesitter' },
  { '<leader>ti', '<cmd>lua Snacks.toggle.indent():toggle()<CR>', desc = '[T]oggle [I]ndent' },
  { '<leader>tf', '<cmd>lua Snacks.toggle.dim():toggle()<CR>', desc = '[T]oggle [F]ocus' },

  -- Picker maps
  -- { '<leader>ef', '<cmd>lua Snacks.picker.buffers({sort_lastused=true})<CR>', desc = '[E]xisting Buffers [F]zf', mode = 'n' },
  -- { '<leader>gc', '<cmd>lua Snacks.picker.git_log()<CR>', desc = 'Fzf [G]it [c]ommit', mode = 'n' },
  -- { '<leader>gs', '<cmd>lua Snacks.picker.git_status()<CR>', desc = 'Fzf [G]it [s]tatus', mode = 'n' },
  -- { '<leader>fh', '<cmd>lua Snacks.picker.help()<CR>', desc = '[F]zf [H]elp tags', mode = 'n' },
  -- { '<leader>fk', '<cmd>lua Snacks.picker.keymaps()<CR>', desc = '[F]zf [K]eymaps', mode = 'n' },
  -- { '<leader>fo', '<cmd>lua Snacks.picker.recent()<CR>', desc = '[F]zf [O]ld files', mode = 'n' },
  -- { '<leader>fl', '<cmd>lua Snacks.picker.grep()<CR>', desc = '[F]zf [G]rep files', mode = 'n' },
  -- { '<leader>ff', '<cmd>lua Snacks.picker.smart()<CR>', desc = '[F]zf [F] files', mode = 'n' },
  -- { '<leader>fs', '<cmd>lua Snacks.picker.lsp_symbols()<CR>', desc = '[F]zf Document [S]ymbols', mode = 'n' },
  -- { '<leader>fn', '<cmd>lua Snacks.picker.files({ cwd = vim.fn.stdpath "config", follow = true })<CR>', desc = '[F]zf [N]eovim Config', mode = 'n' },
  -- { '<leader>f:', '<cmd>lua Snacks.picker.command_history()<CR>', desc = '[F]zf [C]ommands', mode = 'n' },

  -- {
  --   '<leader>N',
  --   desc = 'Neovim News',
  --   function()
  --     require('snacks').bufdelete()
  --     Snacks.win {
  --       file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
  --       width = 0.6,
  --       height = 0.6,
  --       wo = {
  --         spell = false,
  --         wrap = false,
  --         signcolumn = 'yes',
  --         statuscolumn = ' ',
  --         conceallevel = 3,
  --       },
  --     }
  --   end,
  -- },
  --
  --
  -- { '<c-/>', '<cmd>lua Snacks.terminal()<CR>', desc = 'Toggle Terminal' },
  -- { '<c-_>', '<cmd>lua Snacks.terminal()<CR>', desc = 'which_key_ignore' },
  -- { ']]', '<cmd>lua Snacks.words.jump(vim.v.count1)<CR>', desc = 'Next Reference', mode = { 'n', 't' } },
  -- { '[[', '<cmd>lua Snacks.words.jump(-vim.v.count1)<CR>', desc = 'Prev Reference', mode = { 'n', 't' } },
  --
  -- {
  --   '<leader>tb',
  --   "<cmd>lua Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):toggle()<CR>",
  --   desc = '[T]oggle [B]ackground',
  -- },
}

return M
