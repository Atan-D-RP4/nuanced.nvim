local M = {
  'folke/trouble.nvim',
  cmd = 'Trouble',
}

M.keys = {
  { '<leader>xd', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics (Trouble)' },
  { '<leader>xs', '<cmd>Trouble lsp_document_symbols toggle<CR>', desc = 'Symbols (Trouble)' },
  { '<leader>xL', '<cmd>Trouble lsp toggle<CR>', desc = 'LSP Definitions / references / ... (Trouble)' },
  { '<leader>xq', '<cmd>Trouble loclist toggle<CR>', desc = 'Location List (Trouble)' },
  { '<leader>xc', '<cmd>Trouble qflist toggle<CR>', desc = 'Quickfix List (Trouble)' },
}

M.opts = {
  open_no_results = true,
  focus = true,
  win = {
    position = 'bottom',
    width = 100,
  },
  -- modes = {
  --   symbols = {
  --     focus = true,
  --   },
  -- },
}

return M
