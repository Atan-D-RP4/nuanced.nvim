local M = {
  'folke/snacks.nvim',
  lazy = false,
  dependencies = {
    'tpope/vim-sleuth', -- For auto-detecting indent settings
  },
}

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
  { '<leader>gb', '<cmd>lua Snacks.git.blame_line()<CR>', desc = 'Git Blame Line' },
  -- { '<c-/>', '<cmd>lua Snacks.terminal()<CR>', desc = 'Toggle Terminal' },
  -- { '<c-_>', '<cmd>lua Snacks.terminal()<CR>', desc = 'which_key_ignore' },
  -- { ']]', '<cmd>lua Snacks.words.jump(vim.v.count1)<CR>', desc = 'Next Reference', mode = { 'n', 't' } },
  -- { '[[', '<cmd>lua Snacks.words.jump(-vim.v.count1)<CR>', desc = 'Prev Reference', mode = { 'n', 't' } },
  {
    '<leader>N',
    desc = 'Neovim News',
    function()
      require('snacks').bufdelete()
      Snacks.win {
        file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
        width = 0.6,
        height = 0.6,
        wo = {
          spell = false,
          wrap = false,
          signcolumn = 'yes',
          statuscolumn = ' ',
          conceallevel = 3,
        },
      }
    end,
  },

  -- Create some toggle mappings
  { '<leader>ts', "<cmd>lua Snacks.toggle.option('spell', { name = 'Spelling' }):toggle()<CR>" },
  { '<leader>tw', "<cmd>lua Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle()<CR>" },
  { '<leader>tL', "<cmd>lua Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):toggle()<CR>" },
  { '<leader>td', '<cmd>lua Snacks.toggle.diagnostics():toggle()<CR>' },
  { '<leader>tl', '<cmd>lua Snacks.toggle.line_number():toggle()<CR>' },
  { '<leader>tT', '<cmd>lua Snacks.toggle.treesitter():toggle()<CR>' },
  { '<leader>tb', "<cmd>lua Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):toggle()<CR>" },
  { '<leader>ti', '<cmd>lua Snacks.toggle.indent():toggle()<CR>' },
  { '<leader>tf', '<cmd>lua Snacks.toggle.dim():toggle()<CR>' },
}

---@type snacks.Config
M.opts = {
  dim = {
    -- your dim configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
  profiler = { enabled = true },
  bigfile = { enabled = true },
  scope = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  dashboard = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  quickfile = { enabled = true },
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

return M
