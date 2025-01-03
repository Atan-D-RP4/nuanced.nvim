local M = {
  'folke/trouble.nvim',
  cmd = 'Trouble',
}

M.keys = {
  { '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics (Trouble)' },
  { '<leader>cs', '<cmd>Trouble lsp_document_symbols toggle<CR>', desc = 'Symbols (Trouble)' },
  { '<leader>cl', '<cmd>Trouble lsp toggle<CR>', desc = 'LSP Definitions / references / ... (Trouble)' },
  { '<leader>xl', '<cmd>Trouble loclist toggle<CR>', desc = 'Location List (Trouble)' },
  { '<leader>xq', '<cmd>Trouble qflist toggle<CR>', desc = 'Quickfix List (Trouble)' },
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
