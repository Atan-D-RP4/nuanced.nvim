local M = {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  config = function()
    local err, snacks = pcall(require, 'snacks')
    if not err then
      return
    end
    snacks.config.picker = {
      actions = require('trouble.sources.snacks').actions,
      win = { input = { keys = { ['<C-t>'] = { 'trouble_open', desc = 'trouble', mode = { 'i', 'n' } } } } },
    }

    require('trouble').setup()
  end,
}

M.keys = {
  { '<leader>xd', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics (Trouble)' },
  { '<leader>xs', '<cmd>Trouble lsp_document_symbols toggle<CR>', desc = 'Symbols (Trouble)' },
  { '<leader>xL', '<cmd>Trouble lsp toggle<CR>', desc = 'LSP Definitions / references / ... (Trouble)' },
  { '<leader>xl', '<cmd>Trouble loclist toggle<CR>', desc = 'Location List (Trouble)' },
  { '<leader>xq', '<cmd>Trouble qflist toggle<CR>', desc = 'Quickfix List (Trouble)' },
}

M.opts = {
  open_no_results = true,
  focus = true,
  win = {
    position = 'top',
    width = 100,
  },
  -- modes = {
  --   symbols = {
  --     focus = true,
  --   },
  -- },
}

return M
